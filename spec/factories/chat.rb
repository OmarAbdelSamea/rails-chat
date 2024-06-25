require 'faker'

FactoryBot.define do
    factory :chat do
        sequence(:number) { |n| n }
        name { Faker::Superhero.name }
        messages_count { 1 }
        application_token { application.token }
    end
end