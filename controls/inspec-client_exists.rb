inspec_path = input('inspec_path', value: '/bin/inspec')

describe file(inspec_path) do
  it { should exist }
end
