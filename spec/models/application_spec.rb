require 'rails_helper'

RSpec.describe Application, type: :model do
  it { should have_many(:chats) }

  it { should validate_presence_of(:name) }
end
