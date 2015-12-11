require_relative 'ruby_source_file'
require_relative 'java_source_file'
require_relative 'javascript_source_file'
require_relative 'objc_source_file'

class FileRevision

  def initialize(path, repo, batchresults)
    @path = path
    @repo = repo
    @batchresults = batchresults
  end

  def path
    @path
  end

  def complexity_report
    report = @batchresults[@path]

    if report.nil?
      puts "WARN: No batch report for #{@path}"
      report = case @path
               when /.*\.rb$/
                 RubySourceFile.new(@path).complexity
               when /.*\.java$/
                 JavaSourceFile.new(@path).complexity
               when /.*\.m$/
                 ObjCSourceFile.new(@path).complexity
               when /.*\.js$/
                 JavascriptSourceFile.new(@path).complexity
               end
    end

    if report.nil? | report.empty?
      STDOUT.write "WARNING: Could not parse #{@path}"
    else
      print '.' # prints '.' to indicate something is happening 
      e = 1 + report.fetch(:num_dependencies, 1)
      b = 1 + report.fetch(:num_branches, 1)
      s = 1 + report.fetch(:num_superclasses, 1)
      report['weight'] = b * e * s
      report[:churn] = @repo.num_commits_involving(@path)
      report[:filename] = @path
    end
    report
  end

end
