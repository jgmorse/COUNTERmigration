# frozen_string_literal: true

require 'csv'
require 'securerandom'

def create_idno_map
  map = Hash.new
  # The following requires a file in data/map.csv that is the output of
  # sudo -u heliotrope-production RAILS_ENV=production bundle exec rails "heliotrope:handles_publisher[#{publisher}, all]"
  CSV.foreach('data/map.csv') do |line|
    next unless line[2] =~ /heb\d{5}\.\d{4}\.\d{3}/
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

idno_map = create_idno_map
oa_noids = File.readlines('data/heb-monograph-oa-noids.csv', chomp: true)
monograph_epub_map = Hash[*File.read('data/heb-monograph-to-epub-noids.csv').split(/[,\n]/)]


CSV.open('data/output.csv', 'w') do |output|
  output << header_row

  titles_seen = Hash.new(0)

  CSV.foreach(ARGV.shift, headers: true) do |input|
    #Expand each row into one row per hit
    hits = input['total']
    hits.to_i.times {
      row = CSV::Row.new(header_row,[])

      #track which book we're counting in this period
      idno = input['title']
      titles_seen[ idno ]+=1

      row['session'] = "Migrated from DLXS stats for HELIO-3240 on #{DateTime.now} ID:#{SecureRandom.hex(10)}"
      row['institution'] = input['institution']
      noid = idno_map[ idno ]
      row['noid'] = monograph_epub_map[ noid ]
      row['model'] = 'FileSet'
      row['section'] = 'unknown'
      row['section_type'] = 'Chapter'
      row['investigation'] = 1
      row['request'] = 1
      row['turnaway'] = nil
      row['access_type'] = oa_noids.include?(noid) ? 'OA_Gold' : 'Controlled'
      row['created_at'] = input['hitdate']
      row['updated_at'] = input['hitdate']
      row['press'] = 16
      row['parent_noid'] = noid
      # Handy for reviewing and testing output but not otherwise valid:
      # row['hebid'] = idno
      # row['subtype'] = input['subtype']

      if input['subtype'] == 'pdf'
        output << row
      elsif input['subtype'] == 'text'
        output << row
      elsif input['subtype'] == 'pg/img' && titles_seen[ idno ] % 25 == 0
        #Effectively count each page view as 1/25th of a chapter
        output << row
      end
    }
  end
end
