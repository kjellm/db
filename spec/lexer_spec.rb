require 'spec_helper'

describe 'The lexer' do

  subject { SqlParser.new }

  def get_tokens(str)
    subject.scan_setup(str)
    tokens = []
    while (t = subject.next_token)
      tokens << t
    end
    tokens
  end

  it 'tokenizes a plain SQL string' do
    tokens = get_tokens("SELECT * FROM t WHERE x = 1")
    expect(tokens).to eq [
                        [:SELECT, "SELECT"], ["*", "*"],
                        [:FROM, "FROM"], [:NAME, :t],
                        [:WHERE, "WHERE"], [:NAME, :x], ["=", "="], [:VALUE, 1],
                      ]
  end

  it 'has case insensitive keywords' do
    tokens = get_tokens("select *")
    expect(tokens).to eq [[:SELECT, "select"], ["*", "*"]]
  end

end
