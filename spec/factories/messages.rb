require 'faker'

FactoryBot.define do
    factory :message do
        sequence(:number) { |n| n }
        content { Faker::Lorem.paragraph }
        chat_number { 1 }
        application_token { "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
    end
end