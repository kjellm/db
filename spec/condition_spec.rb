require 'spec_helper'

describe Condition do
  describe '#partition' do
    it do
      sel = Condition.new([:"=", :a, 1])
      expect { sel.partition([]) }.to raise_error(RuntimeError)
    end

    it do
      sel = Condition.new([:"=", :a, 1])
      expect { sel.partition(nil) }.to raise_error(RuntimeError)
    end

    it do
      sel = Condition.new([:"=", :a, 1])
      expect(sel.partition([:a])).to eq [[:"=", :a, 1],[]]
    end

    it do
      sel = Condition.new([:"=", :a, 1])
      expect(sel.partition([:b])).to eq [[], [:"=", :a, 1]]
    end

    it do
      sel = Condition.new([:and, [:"=", :a, 1], [:"=", :b, 2]])
      expect(sel.partition([:a])).to eq [[:"=", :a, 1], [:"=", :b, 2]]
    end

    it do
      sel = Condition.new([:or, [:"=", :a, 1], [:"=", :b, 2]])
      expect { sel.partition(:a) }.to raise_error(RuntimeError)
    end

    it do
      sel = Condition.new([:and, [:"=", :a, 1], [:"=", :a, 2]])
      expect(sel.partition([:a])).to eq [[:and, [:"=", :a, 1], [:"=", :a, 2]], []]
    end

  end
end
