# frozen_string_literal: true

require 'csv'
require 'securerandom'

def create_idno_map
  map = Hash.new
  # The following requires a file in data/map.csv that is the output of
  # sudo -u heliotrope-production RAILS_ENV=production bundle exec rails "heliotrope:handles_publisher[#{publisher}, all]"
  CSV.foreach('data/map.csv') do |line|
    next unless line[2]
    # idnos to noids
    map[ line[2] ] = line[0]
  end
  return map
end

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

map = create_idno_map

CSV.open('data/output.csv', 'w') do |output|
  output << header_row

  CSV.foreach(ARGV.shift, headers: true) do |input|
    #Expand each row into one row per hit
    hits = input['total']
    hits.to_i.times {
      row = CSV::Row.new(header_row,[])
      row['session'] = "Migrated from DLXS stats for HELIO-3240 on #{DateTime.now} ID:#{SecureRandom.hex(10)}"
      row['institution'] = input['institution']

      row['noid'] = map[ input['title'] ]

      output << row
    }
  end
end
