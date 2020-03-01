# frozen_string_literal: true

require 'csv'
require 'securerandom'

header_row = [
  'session',
  'institution',
  'noid',
  'model',
  'section',
  'section_type',
  'investigation',
  'request',
  'turnaway',
  'access_type',
  'created_at',
  'updated_at',
  'press',
  'parent_noid'
]

CSV.open('data/output.csv', 'w') do |output|
  output << header_row

  CVS.foreach(ARGV.shift, headers: true) do |input|
    #Expand each row into one row per hit
    hits = input['total']
    hits.times {
      row = CSV::Row.new(header_row,[])
      row['session'] = "Migrated from DLXS stats for HELIO-3240 on #{DateTime.now} ID:#{SecureRandom.hex(10)}"

    }
  end
end
