require 'spec_helper'

describe Optimizer do

  before do
    StorageEngine.build(
      {t: [], t1: [:a], t2: [:b]},
      {t: [], t1: [[1]] * 10, t2: [[2]] * 10}
    )
  end

  describe '#call' do
    it do
      plan = Plan.new([])
      expect(subject.(plan)).to eq plan
    end

    it do
      plan = Plan.new([TableScan.new(:t)])
      expect(subject.(plan)).to eq plan
    end

    it do
      plan = Plan.new([TableScan.new(:t),
                       Selection.new([:"=", :a, 1]),
                       Projection.new([:a, :b]),
                      ])
      expect(subject.(plan)).to eq plan
    end

    it 'moves up conditions that only references first table columns' do
      plan =
        Plan.new([TableScan.new(:t1),
                  CartesianProduct.new(:t2),
                  Selection.new([:"=", :a, 1]),
                 ])
      optimized_plan =
        Plan.new([TableScan.new(:t1),
                  Selection.new([:"=", :a, 1]),
                  CartesianProduct.new(:t2),
                 ])
      expect(subject.(plan)).to eq optimized_plan
    end

    it 'splits conjunctions' do
      plan =
        Plan.new([TableScan.new(:t1),
                  CartesianProduct.new(:t2),
                  Selection.new([:and, [:"=", :a, 1], [:"=", :b, 2]]),
                 ])
      optimized_plan =
        Plan.new([TableScan.new(:t1),
                  Selection.new([:"=", :a, 1]),
                  CartesianProduct.new(:t2),
                  Selection.new([:"=", :b, 2]),
                 ])
      expect(subject.(plan)).to eq optimized_plan
    end

    it 'does nothing with conjunctions' do
      plan =
        Plan.new([TableScan.new(:t1),
                  CartesianProduct.new(:t2),
                  Selection.new([:or, [:"=", :a, 1], [:"=", :b, 2]]),
                 ])
      optimized_plan =
        Plan.new([TableScan.new(:t1),
                  CartesianProduct.new(:t2),
                  Selection.new([:or, [:"=", :a, 1], [:"=", :b, 2]]),
                 ])
      expect(subject.(plan)).to eq optimized_plan
    end
  end
end
