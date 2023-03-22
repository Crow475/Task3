require 'securerandom'
require 'openssl'
require 'terminal-table'

class GameRules
    attr_accessor :moves
    attr_accessor :relations

    def initialize(moves)
        @moves = moves

        @relations = {}
        @moves.each_with_index do |move, i|
            @relations[move] = {}
            @moves.each_with_index do |_, j|
                opponent = @moves[(i + j)%moves.length]
                if j == 0
                    @relations[move][opponent] = 'draw'
                elsif j <= (moves.length - 1)/2
                    @relations[move][opponent] = 'lose'
                else
                    @relations[move][opponent] = 'win'
                end
            end
        end
    end

    def compare(move_a, move_b)
        unless @relations.key?(move_a) && @relations.key?(move_b)
            return
        end
        @relations[move_a][move_b]
    end
end

class MoveGenerator
    attr_accessor :move
    attr_accessor :key
    
    def initialize(moves)
        @available_moves = moves
    end
    
    def pick_move
        @key = SecureRandom.hex(32)
        @move = @available_moves[SecureRandom.random_number(0..@available_moves.length - 1)]
    end

    def generate_hmac
        OpenSSL::HMAC.hexdigest("SHA3-256", @key, @move)
    end
end

class TableGenerator
    def initialize(game_rules)
        @game_rules = game_rules

        @table = Terminal::Table.new do |t|
            t.add_row(["Player:"] + game_rules.relations.keys)
            t.add_separator
            game_rules.relations.values.each_with_index do |value, index|
                row = []
                game_rules.moves.each do |move|
                    row << value[move]
                end
                t.add_row([game_rules.relations.keys[index]] + row)
            end
        end
    end

    def print_table
        puts @table
    end
end

def print_error(error_message)
    STDERR.puts "Error: #{error_message}"
    STDERR.puts 'For example:'
    STDERR.puts 'task3.rb rock paper scissors'
    STDERR.puts 'task3.rb rock spock paper lizzard scissors'
end

def print_controls(moves)
    moves.each_with_index { |move_name, index| puts "#{index + 1} - #{move_name}"}
    puts '0 - Exit'
    puts '? - Help'
end

def prompt_replay()
    puts 'Would you like to play again? [y/n]'
    case STDIN.gets.strip!.downcase
    when 'y'
        true
    when 'n'
        false
    else
        prompt_replay
    end
end

def play(game_rules, computer, table_generator)
    computer.pick_move
    puts "HMAC: #{computer.generate_hmac}"
    print_controls(game_rules.moves)
    while true
        print 'Enter your move: '
        user_input = STDIN.gets.strip!
        if user_input == '0'
            exit(true)
        end
        if user_input == '?'
            table_generator.print_table
        elsif user_input.to_i > 0 && user_input.to_i < game_rules.moves.length + 1
            user_move = game_rules.moves[user_input.to_i - 1]
            puts "Your move: #{user_move}"
            puts "Computer's move: #{computer.move}"
            case result = game_rules.compare(user_move, computer.move)
            when 'draw'
                puts "It's a draw!"
            else
                puts "You #{result}!"
            end
            puts "Key: #{computer.key}"
            unless prompt_replay
                exit(true)
            end
            puts '-----'
            play(game_rules, computer, table_generator)
        else
            puts 'Invalid input!'
            print_controls(game_rules.moves)
        end
    end
end

if __FILE__ == $0
    moves = ARGV
    unless moves.length > 2
        print_error('There must be at least 3 moves!')
        exit(false)
    end
    unless moves == moves.uniq
        print_error('All moves must have unique names!')
        exit(false)
    end
    unless moves.length.odd?
        print_error('There must be an odd number of moves!')
        exit(false)
    end
    
    game_rules = GameRules.new(moves)
    computer = MoveGenerator.new(game_rules.moves)
    table_generator = TableGenerator.new(game_rules)
    
    play(game_rules, computer, table_generator)
end
