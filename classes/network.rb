# network.rb
# describes the network to which the bot is connected

class Network
  attr_reader :name, :currentServer, :serverSoftware, :maxBans, :maxExempts, :maxInviteExempts, :maxNickLength, :maxChannelNameLength, :maxTopicLength, :maxKickLength, :maxAwayLength, :maxTargets, :maxModes, :channelTypes, :prefixes, :channelModes, :caseMapping, :maxChannels
  attr_writer :name, :currentServer, :serverSoftware, :maxBans, :maxExempts, :maxInviteExempts, :maxNickLength, :maxChannelNameLength, :maxTopicLength, :maxKickLength, :maxAwayLength, :maxTargets, :maxModes, :channelTypes, :prefixes, :channelModes, :caseMapping, :maxChannels
=begin
  def initialize(name, currentServer, serverSoftware, maxBans, maxExempts, maxInviteExempts, maxNickLength, maxChannelNameLength, maxTopicLength, maxKickLength, maxAwayLength, maxTargets, maxModes, channelTypes, prefixes, channelModes, caseMapping)
    @name = name
    @currentServer = currentServer
    @serverSoftware = serverSoftware
    @maxBans = maxBans
    @maxExempts = maxExempts
    @maxInviteExempts = maxInviteExempts
    @maxChannelNameLength = maxChannelNameLength
    @maxNickLength = maxNickLength
    @maxTopicLength = maxTopicLength
    @maxKickLength = maxKickLength
    @maxAwayLength = maxAwayLength
    @maxTargets = maxTargets
    @maxModes = maxModes
    @channelTypes = channelTypes
    @prefixes = prefixes
    @channelModes = channelModes
    @caseMapping = caseMapping
  end
=end
end
