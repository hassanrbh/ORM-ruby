require 'sqlite3'
require 'singleton'

class PlayDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('plays.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Play
  attr_accessor :id, :title, :year, :playwright_id

  def self.all
    data = PlayDBConnection.instance.execute("SELECT * FROM plays")
    data.map { |datum| Play.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @year = options['year']
    @playwright_id = options['playwright_id']
  end

  def create
    raise "#{self} already in database" if self.id
    PlayDBConnection.instance.execute(<<-SQL, self.title, self.year, self.playwright_id)
      INSERT INTO
        plays (title, year, playwright_id)
      VALUES
        (?, ?, ?)
    SQL
    self.id = PlayDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless self.id
    new_data = PlayDBConnection.instance.execute(<<-SQL, self.title, self.year, self.playwright_id, self.id)
      UPDATE
        plays
      SET
        title = ?, year = ?, playwright_id = ?
      WHERE
        id = ?
    SQL
    new_data.map { |new_record| Play.new(new_record)}
  end
  def self.find_by_title(title)
    # IF THE TITLE IS NOT IN DATABASE YOU WILL RETURN NIL
    # raise " #{self} Is not in The in database " if self.title != title
    play = PlayDBConnection.instance.execute(<<-SQL , title)
    SELECT
      plays.title
    FROM
      plays
    WHERE
      title = ?
    SQL
    return nil unless play.length > 0
    Play.new(play.first)
  end
  def self.find_by_playwright(name)
    # find plays by the name of the playwright_id
    playwright = Playwright.find_by_name(name) # return a hash of the corresponded name
    raise "#{name} Is not in database" unless playwright
    plays = PlayDBConnection.instance.execute(<<-SQL, playwright.id)
    SELECT
      *
    FROM
      plays
    WHERE
      playwright_id = ?
    SQL
    plays.map { |play_me| Play.new(play_me)}
  end
end
class Playwright
  attr_accessor :id, :name, :birth_year
  def initialize(option)
    @id = option["id"]
    @name = option["name"]
    @birth_year = option["birth_year"]
  end
  def self.all
    playwright = PlayDBConnection.instance.execute("SELECT * FROM playwrights;")
    playwright.map { |datum| Playwright.new(datum)}
  end
  def self.find_by_name(name)
    # Find by name the column of playwrights
    raise "#{name} not found in DB" unless self.name != name
    person = PlayDBConnection.instance.execute(<<-SQL , name)
    SELECT
      *
    FROM
      playwrights
    WHERE
      name = ?
    SQL
    return nil unless person.length > 0
    Playwright.new(person.first)
  end
  def create
    # raise if the id is match
    raise '#{self} Not found in DB' if self.id
    PlayDBConnection.instance.execute(<<-SQL ,self.name, self.birth_year)
    INSERT INTO
      playwrights (name,birth_year)
    VALUES
      ( ? , ? )
    SQL
    self.id = PlayDBConnection.instance.last_insert_row_id
  end
  def update
    raise "#{self} Not found in DB" if self.id
    updated_record = PlayDBConnection.instance.execute(<<-SQL, self.name, self.birth_year, self.id)
    UPDATE
      playwrights
    SET
      name = ?,
      birth_year = ?
    WHERE id = ?
    SQL
    updated_record.map { |record| Playwright.new(record)}
  end
  def get_plays
    raise "#{self} Not found in DB" unless self.id
    plays = PlayDBConnection.instance.execute(<<-SQL self.id)
    SELECT
      *
    FROM
      plays
    WHERE
      playwright_id = ?
    SQL
    plays.map { |record| Play.new(record) }
  end
end
