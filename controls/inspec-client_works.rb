inspec_test = input('inspec_test', value: '/bin/inspec detect --chef-license=accept')

describe bash(inspec_test) do
  its('stdout') { should match /Families/ }
  its('stderr') { should eq ''}
  its('exit_status') { should eq 0 }
end
