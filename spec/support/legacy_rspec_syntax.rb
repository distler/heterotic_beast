RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }
  config.mock_with(:rspec)   { |c| c.syntax = [:should, :expect] }
  config.infer_spec_type_from_file_location!
end
