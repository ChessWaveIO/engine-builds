#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Generate the per-engine config.json that the ChessWave desktop client
# (wavebridge) reads at runtime, derived from the engine.yaml manifest.
#
# Shipping config.json inside each release tarball keeps the client free of a
# YAML parser and works on every client version. The engine binary name is
# taken from the per-platform entry (the top-level `engine` field is not
# platform-specific and must not be used here).
#
# Usage: gen_config_json.rb <engine.yaml> <platform> <out config.json>

require 'yaml'
require 'json'

yaml_path, platform, out_path = ARGV
abort 'usage: gen_config_json.rb <engine.yaml> <platform> <out.json>' unless yaml_path && platform && out_path

data = YAML.load_file(yaml_path) || {}

platforms = data['platforms'] || {}
platform_entry = platforms[platform] || {}
engine = platform_entry['engine'] || data['engine']
if engine.nil? || engine.to_s.strip.empty?
  abort "gen_config_json: no engine binary defined for platform '#{platform}' in #{yaml_path}"
end

config = {
  'id' => data['id'],
  'name' => data['name'],
  'engine' => engine,
  'uci_options' => data['uci_options'] || {},
  'elo' => data['elo'],
  'style' => data['style'],
  'description' => data['description'],
  'author' => data['author'],
  'version' => data['version'],
  'icon' => data['icon'] || '',
  'is_active' => true
}

File.write(out_path, JSON.pretty_generate(config) + "\n")
