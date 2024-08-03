require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
def valid_number(number)
  digits = number.gsub(/\D/, '')
  case digits.length
  when 10
    digits
  when 11
    digits.start_with?('1') ? digits[1..-1] : "invalid"
  else
    "invalid"
  end
end
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end


def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end
puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
hour_registered = Hash.new(0)
day_registered = Hash.new(0)
contents.each do |row|
  id = row[0]
  regdate = row[:regdate]
  hour_registered[Time.strptime(regdate,"%m/%d/%y %k:%M").hour] += 1
  day_registered[Date::DAYNAMES[Time.strptime(regdate,"%m/%d/%y %k:%M").wday]] += 1
  name = row[:first_name]
  number = valid_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end
max_hour =  hour_registered.max_by { |key, value| value}[1]
print "Most active hours are "
hour_registered.each { |key,value| print "#{key}:00 " if value == max_hour }
puts
print "Most active days are "
max_day = day_registered.max_by { |key, value| value}[1]
day_registered.each { |key,value| print "#{key} " if value == max_day }