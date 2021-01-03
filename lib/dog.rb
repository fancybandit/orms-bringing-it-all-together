
class Dog

    attr_accessor :name, :breed
    attr_reader :id

    def initialize(name:, breed:, id: nil)
        @id = id
        self.name = name
        self.breed = breed
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
        );
        SQL

        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = <<-SQL
        DROP TABLE IF EXISTS dogs;
        SQL

        DB[:conn].execute(sql)
    end

    def save
        if @id
            self.update
        else
            sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES (?, ?);
            SQL

            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs;")[0][0]
            self
        end
    end

    def self.create(hash)
        new_dog = self.new(hash)
        new_dog.save
    end

    def update
        sql = <<-SQL
        UPDATE dogs SET name = ?, breed = ?
        WHERE id = ?;
        SQL

        DB[:conn].execute(sql, self.name, self.breed, @id)
    end

    def self.new_from_db(row)
        new_dog = self.new(name: row[1], breed: row[2], id: row[0])
    end
    
    def self.find_by_id(id)
        sql = <<-SQL
        SELECT * FROM dogs
        WHERE id = ?;
        SQL

        DB[:conn].execute(sql, id).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_or_create_by(hash)
        sql = <<-SQL
        SELECT * FROM dogs
        WHERE name = ? AND breed = ?;
        SQL
        
        dog = DB[:conn].execute(sql, hash[:name], hash[:breed])
        if !dog.empty?
            row = dog.flatten
            dog = self.new_from_db(row)
        else
            dog = self.create(hash)
        end
        dog
    end

    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * FROM dogs
        WHERE name = ?;
        SQL
        
        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end
end

