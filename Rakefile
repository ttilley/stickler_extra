require 'pathname'
require 'yaml'
require 'bundler/setup'
require 'stickler'
require 'rubygems/mirror'
require 'rubygems/format'


$top = Pathname.new(__FILE__).dirname.expand_path
$data = $top.join('data')
$local = $data.join('local')
$mirror = $data.join('mirror')
$mirrorrc = $data.join('mirrorrc.yml')
$upstream = 'http://production.cf.rubygems.org/'
$mirror_config = [{'from' => $upstream, 'to' => $mirror.to_s}]


class Gem::Mirror
  def update_gems
    gems_to_fetch.each do |g|
      @pool.job do
        @fetcher.fetch(from('gems', g), to('gems', g))
        begin
          write_specification_for_gem(g, to('gems'), to('specifications'))
        rescue => e
          puts e
        end
        yield if block_given?
      end
    end

    @pool.run_til_done
  end

  def delete_gems
    gems_to_delete.each do |g|
      @pool.job do
        begin
          remove_specification_for_gem(g, to('gems'), to('specifications'))
        rescue => e
          puts e
        end
        File.delete(to('gems', g))
        yield if block_given?
      end
    end

    @pool.run_til_done
  end

  private

  def remove_specification_for_gem(gem_file, gem_dir, spec_dir)
    gem_path = File.join(gem_dir, gem_file)
    spec = specification_from_gem_file(gem_path)
    spec_path = File.join(spec_dir, spec.spec_name)
    rm_rf spec_path
  end

  def write_specification_for_gem(gem_file, gem_dir, spec_dir)
    gem_path = File.join(gem_dir, gem_file)
    spec = specification_from_gem_file(gem_path)
    spec_path = File.join(spec_dir, spec.spec_name)
    File.open(spec_path, 'w+') {|file| file << spec.to_ruby}
  end

  def specification_from_gem_file(path)
    Gem::Format.from_file_by_path(path).spec
  end
end


task :create_paths do
  [$local, $mirror].each do |type|
    ['gems', 'specifications'].each do |subdir|
      mkdir_p type.join(subdir)
    end
  end
end

task :configure_mirror => :create_paths do
  File.open($mirrorrc, 'w+') do |file|
    file << $mirror_config.to_yaml
  end unless $mirrorrc.exist?
end

desc 'update local mirror(s) from remote'
task :mirror => :configure_mirror do
  configs = YAML.load_file($mirrorrc)
  configs.each do |config|
    mirror = Gem::Mirror.new(config['from'], File.expand_path(config['to']), 15)
    puts "Fetching: #{mirror.from(Gem::Mirror::SPECS_FILE_Z)}"
    mirror.update_specs
    puts "Total gems: #{mirror.gems.size}"
    num_to_fetch = mirror.gems_to_fetch.size
    puts "Fetching #{num_to_fetch} gems"
    mirror.update_gems #{ print '.' }
    num_to_delete = mirror.gems_to_delete.size
    puts "Deleting #{num_to_delete} gems"
    mirror.delete_gems #{ print '.' }
  end
end
