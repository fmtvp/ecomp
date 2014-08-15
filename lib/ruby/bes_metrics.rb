require_relative 'file_revision'
require_relative 'revision_summary'
require_relative 'complexity_trend_report'
require_relative 'developer_behaviour_report'
require_relative 'current_hotspots_report'

class BesMetrics

  def initialize(repo, report, metrics_dao, glob='*/**/*.*')
    @repo = repo
    @report = report
    @metrics_dao = metrics_dao
    @glob = glob
  end

  def collect
    @repo.reset
    revisions = find_revisions_not_already_analysed

    if revisions.empty?
      puts "Latest revision already analysed"
    else
      # TODO append to JSON file (rather than blitz)
      # TODO extract file writing to DAO
      summaries = revisions.map {|rev| RevisionSummary.new(rev, @repo, @glob) }
      summaries = record_complexity_deltas(summaries)
      # @report.update('current_files', CurrentHotspotsReport.new(@repo, @glob))
      @report.update('commits', ComplexityTrendReport.new(summaries))
      # @report.update('recent_commits_by_author', DeveloperBehaviourReport.new(summaries))
    end

    @repo.reset
  end

  private

  def find_revisions_not_already_analysed
    last_analysed_commit = @metrics_dao.last_commit

    if last_analysed_commit.nil?
      revisions = @repo.all_revisions_oldest_first
    else
      last_found = false
      revisions = Array.new
      @repo.all_revisions_oldest_first.each do |commit|
        if last_found
          revisions << commit
        end
        last_found = true if commit[:ref] == last_analysed_commit
      end
    end

    return revisions
  end

  def record_complexity_deltas(summaries)
    startTime = Time.now
    totalSummaries = summaries.length
    summaries.each_with_index do |summary, i|
      start = Time.now
      puts ("Summary (" + (i+1).to_s + " / " + totalSummaries.to_s + ")")
      delta = summary.sum_of_file_weights - (i > 0 ? summaries[i-1].sum_of_file_weights : 0)
      summary.set_delta(delta)
      timeTaken = Time.now - start
      puts ("Summary completed in " + ('%.2f' % timeTaken.to_s) + "s Estimated completion time: " + ('%.2f' % (timeTaken * (totalSummaries - i))).to_s + "s" )
    end
    puts("Total time taken recording complexity deltas: " + ('%.2f' % (Time.now - startTime)) + "s")
    summaries
  end

end
