require 'spec_helper'

describe Selection do

  subject { described_class.new(sexpr) }

  let(:sexpr) { [:"=", :a, 1] }

  describe '#cost' do
    it do
      expect(subject.cost(0)).to eq [0, 0]
    end

    it do
      expect(subject.cost(10)).to eq [10, 1]
    end

    context do
      let(:sexpr) { [:or, [:"=", :a, 1], [:"=", :a, 2]] }

      it do
        rows = 10
        expect(subject.cost(rows)).to eq [rows, rows]
      end
    end
  end

  describe '#call' do
    # Mostly covered by the specs on Condition

    it do
      expect(subject.call([], [:a])).to eq([[], [:a]])
    end

    it do
      expect(subject.call([[1], [2]], [:a])).to eq([[[1]], [:a]])
    end
  end
end
