class ShortenedUrl < ApplicationRecord
  validates :slug, presence: true, uniqueness: true, length: { minimum: 4, maximum: 16 }
  validates :target, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[https])
end
