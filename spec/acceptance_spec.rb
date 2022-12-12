require 'spec_helper'

describe Db do
  let(:schema) do
    {
      r: Set[:a, :b],
      t: Set[:c],
    }
  end

  let(:data) do
    {
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
  end

  subject { described_class.new(schema, data) }

  def assert_query(query, expected_schema, expected_rows)
    res, res_schema = subject.execute_query(query)
    expect(res_schema).to eq(expected_schema)
    expect(res.length).to eq(expected_rows.length)
    expect(res).to include(*expected_rows)
  end

  it do
    assert_query("SELECT * FROM t", %I[c], [[1], [2], [3]])
  end

  it do
    assert_query(
      "SELECT a, b, c FROM t,r WHERE a = 1 AND b = 2 AND c = 3",
      %I[a b c],
      [[1, 2, 3]]
    )
  end

  it do
    assert_query(
      "SELECT a, b, c FROM t,r WHERE a = 1 AND b = 2 OR c = 3",
      %I[a b c],
      [[1, 1, 3],
       [1, 2, 1],
       [1, 2, 2],
       [1, 2, 3],
       [3, 3, 3]]
    )
  end

  it do
    assert_query("SELECT count(*) FROM t", %I[count], [[3]])
  end

end
