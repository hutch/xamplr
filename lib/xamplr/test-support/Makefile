
ut:
	@rm -rf tmp tmp1 tmp2 ut.results
	@echo "test.rb" >> ut.results
	@ruby -w test.rb | tee -a ut.results
	@echo "test-rollback.rb" >> ut.results
	@ruby -w test-rollback.rb | tee -a ut.results
	@echo "test-deep-change.rb" >> ut.results
	@ruby -w test-deep-change.rb | tee -a ut.results
	@echo "test-cache.rb" >> ut.results
	@ruby -w test-cache.rb | tee -a ut.results
	@echo "test-elements.rb" >> ut.results
	@ruby test-elements.rb | tee -a ut.results
	@echo "test-indexed-array.rb" >> ut.results
	@ruby -w test-indexed-array.rb | tee -a ut.results
	@echo "test-misc.rb" >> ut.results
	@ruby -w test-misc.rb | tee -a ut.results
	@echo "test-names.rb" >> ut.results
	@ruby -w test-names.rb | tee -a ut.results
	@echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	@grep errors ut.results

profile:
	#ruby -r rbprof uche3.rb  > junk 2> results.profile
	ruby -r rbprof uche.rb  > junk 2> results.profile

wc:
	@echo "screwing around -------------------------------"
	@wc bench.rb play.rb
	@echo "unit tests ------------------------------------"
	@wc test.rb
	@echo "example ---------------------------------------"
	@wc example.rb
	@echo "xampl itself ----------------------------------"
	@wc from-xml.rb mixins.rb persistence.rb to-xml.rb xampl-object.rb xampl.rb
	@echo "xampl-pp extra---------------------------------"
	@wc xampl-pp/chew.rb xampl-pp/chewMultibyte.rb xampl-pp/chewRexml.rb xampl-pp/chewRexmlPP.rb xampl-pp/dump.rb
	@echo "stuff------------------------------------------"
	@wc xampl-pp/parse-wf.rb xampl-pp/parse.rb xampl-pp/parseR.rb
	@echo "xampl-pp --------------------------------------"
	@wc xampl-pp/saxdemo.rb xampl-pp/saxish.rb xampl-pp/saxishHandler.rb xampl-pp/xampl-pp-dtd.rb xampl-pp/xampl-pp-wf.rb xampl-pp/xampl-pp.rb
	@echo "alternate--------------------------------------"
	@wc xampl-pp/xpp.rb xampl-pp/xppDeluxe.rb xampl-pp/xppIter.rb

wc0:
	@wc bench.rb play.rb test.rb example.rb from-xml.rb mixins.rb persistence.rb to-xml.rb xampl-object.rb xampl.rb xampl-pp/chew.rb xampl-pp/chewMultibyte.rb xampl-pp/chewRexml.rb xampl-pp/chewRexmlPP.rb xampl-pp/dump.rb xampl-pp/parse-wf.rb xampl-pp/parse.rb xampl-pp/parseR.rb xampl-pp/saxdemo.rb xampl-pp/saxish.rb xampl-pp/saxishHandler.rb xampl-pp/xampl-pp-dtd.rb xampl-pp/xampl-pp-wf.rb xampl-pp/xampl-pp.rb xampl-pp/xpp.rb xampl-pp/xppDeluxe.rb xampl-pp/xppIter.rb

