require_relative 'thread_pool'

tp = ThreadPool.new 500
(1..1000).each { |i| tp.process { (2..10).inject(1) { |memo,val| sleep(0.1); memo*val }; print "Computation #{i} done. Nb of tasks: #{tp.size}\n" } }
tp.shutdown