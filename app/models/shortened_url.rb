class ShortenedUrl < ApplicationRecord
  validates :slug, presence: true, uniqueness: true, length: { minimum: 4, maximum: 16 }, format: { with: /\A\/[a-zA-Z]+\z/, message: "only allows slash followed by letters" }
  validates :target, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[https]), message: "must be a valid https:// URL" }
end
