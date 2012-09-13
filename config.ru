require 'pathname'
require 'rubygems' if RUBY_VERSION < "1.9"
require 'stickler/middleware/compression'
require 'stickler/middleware/gemcutter'
require 'stickler/middleware/mirror'
require 'stickler/middleware/index'
require 'stickler/middleware/not_found'
require 'rack/commonlogger'

data_dir = Pathname.new(__FILE__).dirname.expand_path.join('data')
local_dir = data_dir.join('local')
mirror_dir = data_dir.join('mirror')

if ENV['STICKLER_USER'] and ENV['STICKLER_PASS']
  use Rack::Auth::Basic, 'Secure Stickler' do |user,pass|
    (user == ENV['STICKLER_USER']) and (pass == ENV['STICKLER_PASS'])
  end
end

use Stickler::Middleware::Compression
use Stickler::Middleware::Gemcutter,  :serve_indexes => false, :repo_root => local_dir
use Stickler::Middleware::Mirror,     :serve_indexes => false, :repo_root => mirror_dir
use Stickler::Middleware::Index,      :serve_indexes => true
use Stickler::Middleware::NotFound
run Sinatra::Base
