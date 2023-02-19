# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phonenumber(number)
  number.tr!('^0-9', '')
  number.slice!(0) if number.length != 10 && number[0] == '1'
  return Array.new(10, '0').join unless number.length == 10

  number
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_form_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manger Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

peak_hours = Hash.new(0)
peak_days = Hash.new(0)

contents.each do |row|
  id = row[0]

  date = DateTime.strptime(row[1], '%m/%d/%Y %H:%M')
  hour = date.hour
  day = date.strftime('%A')

  peak_hours[hour] += 1
  peak_days[day] += 1

  zipcode = clean_zipcode(row[:zipcode])
  _legislators = legislators_by_zipcode(zipcode)
  _name = row[:first_name]

  form_letter = erb_template.result(binding)

  save_form_letter(id, form_letter)
end

puts "Peak hours are: #{peak_hours.sort_by(&:last).reverse.to_h}"
puts "Peak days are: #{peak_days.sort_by(&:last).reverse.to_h}"
