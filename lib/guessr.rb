require "guessr/version"
require "set"
require "camping"

Camping.goes :Guessr

module Guessr
  module Models
    class Player < Base
      validates :name, presence: true, uniqueness: true
      #alternately validates :name, presence: true
    end

    class NumberGuessing < Base
      validates :number, presence: true,
        format: {with: /\A[1-9]+\z/, message: 'only digits are allowed'}
      before_save :set_finished!, if: :finished?

      def guess_number(number)
        self.guess = number
      end

      private
      def finished?
        !self.continue?
      end

      def set_finished!
        self.finished = true
      end
    end

    class Hangman < Base
      validates :answer, presence: true,
        format: { with: /\A[a-z]+\z/, message: "only lowercase words allowed"}
      serialize :guesses
      before_save :set_finished!, if: :finished?

      def guess_letter(letter)
        self.guesses.add(letter)
        self.turns -= 1 unless self.answer.include?(letter)
      end

      private
      def finished?
        self.turns.zero? || self.answer.chars.all? { |l| self.guesses.include?(l) }
      end

      def set_finished!
        self.finished = true
      end
    end

    class BasicSchema < V 1.0
      def self.up
        create_table Player.table_name do |t|
          t.string :name
          t.timestamps
        end

        create_table Hangman.table_name do |t|
          t.integer :turns, :default => 7
          t.string :answer
          t.string :guesses
          t.boolean :finished
          t.timestamps
        end
      end

      def self.down
        drop_table Player.table_name
        drop_table Hangman.table_name
      end
    end

    class NumberGuessingSchema < V 1.1
      def self.up
        create_table Player.table_name do |t|
          t.string :name
          t.timestamps
        end

        create_table NumberGuessing.table_name do |t|
          t.integer :number
          t.integer :guess
          t.boolean :finished
          t.timestamps
        end
      end

      def self.down
        drop_table Player.table_name
        drop_table NumberGuessing.table_name
      end
    end

    class AddPlayerIdToHangman < V 1.1
      def self.up
        add_column Hangman.table_name, :player_id, :integer
      end

      def self.down
        remove_column Hangman.table_name, :player_id
      end
    end
  end
end

def Guessr.create
  Guessr::Models.create_schema
end
