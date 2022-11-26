require_relative '../db'

RSpec.configure do |c|
  c.before(:each) do
    StorageEngine.build({},{})
  end

  c.before(:all) do
    $stdout = StringIO.new
  end

  c.after(:all) do
    buf = $stdout
    $stdout = STDOUT
    File.write('test.log', buf.string, mode: 'a')
  end
end
