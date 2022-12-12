# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'awesome_print'
require 'forwardable'
require 'pry-byebug'
require 'set'
require 'tty-table'

require_relative 'parser'

class StorageEngine

  attr_reader :schema, :data

  private_class_method :new, :allocate

  def self.build(schema, data)
    @instance = send(:new, schema, data)
  end

  def self.instance
    raise unless @instance

    @instance
  end

  def initialize(schema, data)
    @schema = schema
    @data = data
  end
end

module Registry
  def schema = StorageEngine.instance.schema

  def data = StorageEngine.instance.data
end

TableScan = Struct.new(:table) do
  include Registry

  def call(_res, _res_schema)
    res_schema = schema.fetch(table).to_a
    res = data.fetch(table)
    [res, res_schema]
  end

  def cost(_rows)
    [data.fetch(table).length] * 2
  end

  def inspect
    "TableScan(#{table})"
  end
  alias to_s inspect
end

CartesianProduct = Struct.new(:table) do
  include Registry

  def call(res, res_schema)
    res = product(res, data.fetch(table))
    res_schema += schema.fetch(table).to_a
    [res, res_schema]
  end

  def cost(rows)
    [rows * data.fetch(table).length] * 2
  end

  def inspect
    "CartesianProduct(#{table})"
  end
  alias to_s inspect

  private

  def product(tab1, tab2)
    res = []
    tab1.each do |i|
      tab2.each do |j|
        res << i + j
      end
    end
    res
  end
end

class Selection

  attr_reader :condition

  def initialize(condition)
    @condition = Condition.new(condition)
  end

  def call(res, res_schema)
    return [res, res_schema] if condition.tautology?

    map = res_schema.zip(0...res_schema.length).to_h
    res.select! do |row|
      condition.evaluate(row, map)
    end
    [res, res_schema]
  end

  def conjunction? = condition.conjunction?
  def tautology? = condition.tautology?

  def partition(columns)
    condition.partition(columns).map {|c| self.class.new(c)}
  end

  def cost(rows)
    est = if conjunction?
            (rows * 0.1).ceil
          else
            rows
          end
    [rows, est]
  end

  def inspect
    "Selection(#{condition})"
  end
  alias to_s inspect

  def ==(other)
    self.class == other.class && condition == other.condition
  end
end

Projection = Struct.new(:columns) do
  def call(res, res_schema)
    return [res, res_schema] if columns == '*'

    if columns == :count
      [[[res.length]], [:count]]
    else
      column_indices = res_schema.map.with_index { |c, i| i if columns.include?(c) }.compact
      res.map! { |row| row.values_at(*column_indices) }
      [res, columns]
    end
  end

  def cost(rows)
    case columns
    when '*'
      [ 0, rows ]
    when :count
      [ rows, 1 ]
    else
      [rows, rows]
    end
  end

  def inspect
    "Projection(#{columns})"
  end

end

Condition = Struct.new(:sexpr) do

  def tautology? = sexpr.empty?

  def conjunction?(e = sexpr)
    op, left, right = *e
    return false if op == :or

    left  = left.is_a?(Array)  ? conjunction?(left)  : true
    right = right.is_a?(Array) ? conjunction?(right) : true

    left && right
  end

  def partition(columns, x = [], y = []) # FIXME: x, y are bad names
    partition_helper(sexpr, columns, x, y)

    [make_conjecture(x), make_conjecture(y)]
  end

  def evaluate(row, map, e = sexpr)
    op, left, right = *e
    left  = evaluate(row, map, left)  if left.is_a?(Array)
    right = evaluate(row, map, right) if right.is_a?(Array)
    case op
    when :or
      left || right
    when :and
      left && right
    when :"="
      row[map[left]] == right
    else
      raise
    end
  end

  def inspect = sexpr.inspect
  alias to_s inspect

  private

  def partition_helper(e, columns, with, without)
    op, left, right = *e

    raise if columns.nil? || columns.empty?

    case op
    when :"="
      if columns.include?(left)
        with << [op, left, right]
      else
        without << [op, left, right]
      end
    when :and
      partition_helper(left, columns, with, without)
      partition_helper(right, columns, with, without)
    else
      raise "Unknown relation operation: #{op}"
    end
  end

  def make_conjecture(relations)
    return relations.flatten if relations.length <= 1

    right = make_conjecture(relations[1..-1])
    right = right.first if right.length == 1
    [:and, relations[0], right]
  end
end

class Plan
  extend Forwardable

  attr_reader :steps

  # FIXME: clean up this interface
  def_delegators :@steps, :index, :insert, :each, :[], :[]=, :any?, :first, :delete_at

  def initialize(steps)
    @steps = steps
  end

  def to_s
    est_rows = 0
    str = steps.map do |s|
      scost, est_rows = s.cost(est_rows)
      "#{s.inspect} Cost: #{scost}, Size: #{est_rows}"
    end.join("\n|> ")
    str << "\nTotal cost: #{cost}\n\n"
  end

  def cost
    total = 0
    est_rows = 0
    steps.each do |s|
      cost, est_rows = s.cost(est_rows)
      total += cost
    end
    total
  end

  def contains_product? = @steps.any? { |s| s.is_a? CartesianProduct }

  def initialize_copy(_original)
    @steps = @steps.clone
  end

  def ==(other)
    self.class == other.class && steps == other.steps
  end

end

class Optimizer
  include Registry

  def call(naive_plan)
    optimized_plan = naive_plan.clone
    split_selection_if_cartesian_product(optimized_plan)
    puts optimized_plan
    cheepest(naive_plan, optimized_plan)
  end

  private

  def split_selection_if_cartesian_product(plan)
    selection_index = plan.index { |s| s.is_a? Selection }
    return unless selection_index

    selection = plan[selection_index]
    if selection.conjunction? && plan.contains_product?
      sel1, sel2 = selection.partition(schema.fetch(plan.first.table))
      if sel2.tautology?
        plan.delete_at(selection_index)
      else
        plan[selection_index] = sel2
      end
      plan.insert(1, sel1) unless sel1.tautology?
    end
  end

  def cheepest(naive_plan, optimized_plan)
    optimized_plan.cost < naive_plan.cost ? optimized_plan : naive_plan
  end

end

class Db

  def initialize(schema, data)
    StorageEngine.build(schema, data)
  end

  def execute_query(sql)
    naive_query_plan = Plan.new(SqlParser.new.parse(sql))

    puts naive_query_plan

    plan = Optimizer.new.(naive_query_plan)

    puts plan

    res = []
    res_schema = []

    plan.each do |step|
      res, res_schema = *step.(res, res_schema)
    end

    # ap [res_schema, res]

    [res, res_schema]
  end
end

def print_result(res, res_schema)
  table = TTY::Table.new(res_schema, res)
  puts table.render(:unicode, padding: [0, 1, 0, 1], indent: 2)
end

if __FILE__ == $0
  schema = {
    r: Set[:a, :b],
    t: Set[:c],
  }

  data = {
    r: [
      [1, 1],
      [1, 2],
      [3, 3],
    ],
    t: [
      [1],
      [2],
      [3],
    ],
  }

  require 'json'
  world = JSON.parse(File.read('world.json'), {symbolize_names: true})
  world[:schema].each_value {|v| v.map!(&:to_sym)}
  schema.merge!(world[:schema])
  data.merge!(world[:data])

  sql = ARGV.join(' ')
  res, res_schema = Db.new(schema, data).execute_query(sql)
  print_result(res, res_schema)
end
