require 'spec_helper'

describe CartesianProduct do

  before do
    StorageEngine.build(
      {t: [:a]},
      {t: [[1]] * 10}
    )
  end

  subject { described_class.new(:t) }

  describe '#cost' do
    it do
      expect(subject.cost(0)).to eq [0, 0]
    end

    it do
      expect(subject.cost(1)).to eq [10, 10]
    end

    it do
      expect(subject.cost(10)).to eq [100, 100]
    end
  end

  describe '#call' do
    it do
      expect(subject.call([], [])).to eq([[], [:a]]) # FIXME: correct behaviour?
    end

    it do
      expect(subject.call([[2]], [:b])).to eq([[[2, 1]]*10, [:b, :a]])
    end
  end
end
