$LOAD_PATH.unshift("../../../xamplr-pp")
$LOAD_PATH.unshift("../../xamplr")

require 'fileutils'
require 'fastercsv'
require 'tokyocabinet'

module RawTokyoCabinet
  include TokyoCabinet

  def RawTokyoCabinet.note_errors(msg="TokyoCabinet Error:: %s\n")
    result = yield

    rmsg = nil
    unless result then
      rmsg = sprintf(msg, @tc_db.errmsg(@tc_db.ecode))
      STDERR.printf(rmsg)
      caller(0).each do |trace|
        STDERR.puts(trace)
      end
    end
    return rmsg
  end

  start_at = Time.now

  arr_of_arrs = FasterCSV.read("random-names.csv")

  parsed_at = Time.now

  @tc_db = TDB.new
  RawTokyoCabinet.note_errors("TC:: tuning error: %s\n") do
    @tc_db.tune(-1, -1, -1, TDB::TDEFLATE)
  end

  FileUtils.mkdir_p('repo/raw') unless File.exist?('repo/raw')

  10.times do | iter |
    RawTokyoCabinet.note_errors("TC:: open error: %s\n") do
      @tc_db.open('repo/raw/repo.tct', TDB::OWRITER | TDB::OCREAT | TDB::OLCKNB ) #TDB::OTSYNC slows it down by almost 50 times
    end

    # Don't care if there are errors (in fact, if the index exists a failure is the expected thing)
    %w{ surname city state email }.each do | index_name |
      @tc_db.setindex(index_name, TDB::ITLEXICAL | TDB::ITKEEP)
    end

    $tc_time = 0
    record_count = @tc_db.rnum()

    inner_start = Time.now

    arr_of_arrs.each_with_index do | row, i |

      #    indexes = {
      #            'surname' => row[1],
      #            'city' => row[3],
      #            'state' => row[4],
      #            'email' => row[6]
      #    }

      data = {
              'given_name' => row[0],
              'surname' => row[1],
              'street_address' => row[2],
              'city' => row[3],
              'state' => row[4],
              'postal_code' => row[5],
              'email' => row[6],
              'phone' => row[7]
      }

      RawTokyoCabinet.note_errors("TC:: write error: %s\n") do
        start = Time.now
        @tc_db.put("person-#{ record_count + i }", data)
        $tc_time += Time.now - start
      end

    end

    final_count = @tc_db.rnum

    RawTokyoCabinet.note_errors("TC:: close error: %s\n") do
      @tc_db.close
    end

    processed_at = Time.now

    p "parsed in #{ parsed_at - start_at }, processed in: #{ processed_at - parsed_at }"
    p "starting at #{ record_count } records, now with: #{ final_count }"
  end

end
