require_relative 'kvh_beam_channels'

puts KvhBeamChannels.beam_channels.to_xml(:root => 'beam_channel_settings')

