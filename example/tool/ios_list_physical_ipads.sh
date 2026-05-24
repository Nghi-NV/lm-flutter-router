#!/usr/bin/env bash
set -euo pipefail

OUTPUT_JSON="$(mktemp -t lm_ios_devices.XXXXXX.json)"
OUTPUT_ERR="$(mktemp -t lm_ios_devices.XXXXXX.err)"
trap 'rm -f "${OUTPUT_JSON}" "${OUTPUT_ERR}"' EXIT

if ! xcrun devicectl list devices --json-output "${OUTPUT_JSON}" \
  >/dev/null 2>"${OUTPUT_ERR}"; then
  cat "${OUTPUT_ERR}" >&2
  exit 1
fi

ruby -rjson -e '
  data = JSON.parse(File.read(ARGV[0]))
  devices = data.dig("result", "devices") || []
  ipads = devices.select do |device|
    device.dig("hardwareProperties", "reality") == "physical" &&
      device.dig("hardwareProperties", "deviceType") == "iPad"
  end

  if ipads.empty?
    warn "No physical iPad found by devicectl."
    physical_ios = devices.select do |device|
      device.dig("hardwareProperties", "reality") == "physical" &&
        ["iPad", "iPhone"].include?(device.dig("hardwareProperties", "deviceType"))
    end
    unless physical_ios.empty?
      warn "Physical iOS devices currently visible:"
      physical_ios.each do |device|
        name = device.dig("deviceProperties", "name")
        udid = device.dig("hardwareProperties", "udid")
        type = device.dig("hardwareProperties", "deviceType")
        model = device.dig("hardwareProperties", "marketingName")
        tunnel = device.dig("connectionProperties", "tunnelState")
        warn "- name=#{name} type=#{type} udid=#{udid} model=#{model} tunnel=#{tunnel}"
      end
    end
    warn "Connect and unlock the iPad, then rerun this script."
    exit 1
  end

  puts "physical_ipads:"
  ipads.each do |device|
    name = device.dig("deviceProperties", "name")
    udid = device.dig("hardwareProperties", "udid")
    model = device.dig("hardwareProperties", "marketingName")
    tunnel = device.dig("connectionProperties", "tunnelState")
    developer = device.dig("deviceProperties", "developerModeStatus")
    puts "- name=#{name} udid=#{udid} model=#{model} tunnel=#{tunnel} developerMode=#{developer}"
  end
' "${OUTPUT_JSON}"
