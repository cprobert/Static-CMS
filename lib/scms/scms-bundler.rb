module ScmsBundler
    require 'fileutils'
    require 'scms/scms-bundler.rb'

    def ScmsBundler.run()
		Dir.glob('**/*.bundle').each do|bundle|
			ScmsBundler.bundle(bundle)
		end
    end

    def ScmsBundler.bundle(bundle)
    	puts "Parsing bundle: #{bundle}"


    	content = ""
		if File::exists?(bundle)
			wd = File.dirname(bundle)
            

			File.readlines(bundle).each do |line|
				bundleFile = line.strip
				bundleFile = bundleFile.gsub('\n', '')

				next  if bundleFile == nil
				next  if bundleFile == ""

				if !line.match(/^#/)
					b = File.join(wd, bundleFile)
					puts "Including: #{line}"
					if File::exists?(b)
						content +=  File.read(b) + "\n"
					else
						puts "Can not read: #{b}"
					end
				end
			end

			out = ScmsBundler.getGeneratedBundleName(bundle)
			begin
                File.open(out, 'w') {|f| f.write(content) }
                ScmsUtils.successLog("Created: #{out}")
			rescue Exception=>e
                ScmsUtils.errLog("Error creating bundle: #{out}")
                ScmsUtils.errLog(e.message)
                ScmsUtils.log(e.backtrace.inspect)
			end
		end
    end

    def ScmsBundler.watch()
    	# Listen to changes to files withing a bundle
	    Dir.glob('**/*.bundle').each do|bundle|
			ScmsBundler.watchBundle(bundle)
		end	
    end

    def ScmsBundler.watchBundle(bundle)
    	files = ScmsBundler.getBundleFiles(bundle)
    	Thread.new {
			FileWatcher.new(files).watch do |filename|
				begin
					ScmsBundler.bundle(bundle)
				rescue Exception=>e
	                ScmsUtils.errLog(e.message)
	                ScmsUtils.log(e.backtrace.inspect)
				end
			end
    	}
    end

    def ScmsBundler.getBundleFiles(bundle)
    	files = []
		if File::exists?(bundle)
			wd = File.dirname(bundle)
			File.readlines(bundle).each do |line|
				bundleFile = line.strip
				bundleFile = bundleFile.gsub('\n', '')

				next  if bundleFile == nil
				next  if bundleFile == ""
				next if line.match(/^generate:/)

				if !line.match(/^#/)
					b = File.join(wd, bundleFile)
					if File::exists?(b)
						files << b
					end
				end
			end
		end
		return files
    end

    def ScmsBundler.getGeneratedBundleName(bundle)
		name = bundle.gsub(".bundle", "")

		if File::exists?(bundle)
			wd = File.dirname(bundle)
			File.readlines(bundle).each do |line|
				if line.match(/^generate:/)
					name = File.join(wd, line.gsub("generate:", "").strip)
					break
				end
			end
		end
    	return name
    end
end