#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2013 Kyle Johnson <kyle@vacantminded.com>
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

register 'Drink more whiskey!'

command 'shots', 'Check or reset your shot counter. Syntax: [RESET|RECORD]' do
  unless @params.empty?
    case @params.first.strip.downcase

    when 'reset'
      reset_shots
      reply 'Your shot counter has been reset.'

    when 'record'
      reply "Your personal record is \002#{get_max_shots}\002 shots."

    else
      raise 'Unknown action. Syntax: RESET|RECORD'

    end
    
    next
  end

  reply "You have had \002#{get_shots['shots']}\002 shots."
end

command 'shot', 'Drink a shot, incrementing your shot counter.' do
  add_shot

  reply 'Shot counter incremented.'
end

helpers do

  def get_shots
    network_shots = get_data(@connection.name, Hash.new)
    network_shots.fetch @msg.nick_canon, Hash.new(0)
  end

  def get_max_shots
    get_shots['record']
  end

  def add_shot
    shots     = get_data @connection.name, Hash.new
    my_shots  = shots.fetch @msg.nick_canon, Hash.new(0)

    my_shots['shots'] += 1

    if my_shots['shots'] > my_shots['record']
      my_shots['record'] = my_shots['shots']
    end

    shots[@msg.nick_canon] = my_shots

    store_data @connection.name, shots
  end

  def reset_shots
    shots = get_data @connection.name, Hash.new
    
    unless shots.has_key? @msg.nick_canon
      return
    end

    shots[@msg.nick_canon]['shots'] = 0

    store_data @connection.name, shots
  end

end

# vim: set tabstop=2 expandtab:
