# frozen_string_literal: true

def setup # rubocop:disable Metrics/PerceivedComplexity
  @branch = ''
  @message = ''
  @has_message = false

  args = ARGV.dup
  while args.any?
    case (arg = args.shift)
    when '-m'
      @message = args.shift
      @has_message = true
    else
      @branch = arg
    end
  end

  # commit 6b298e1363098e8dbb8c890772b3a6b3ab7bba09
  # Author: Miller Arlindo Hall <miller.hall@shopify.com>
  # date:   fri jun 6 18:46:45 2025 -0400
  show = `git show --stat`
  author = /Author: ([\w\s]+)<(.*?)>/.match(show)&.captures&.last&.to_s
  head_message = /^    .+/.match(show)&.to_s&.strip
  has_no_diff = `git diff HEAD`.empty?

  is_wip = head_message&.start_with?('wip:') == true
  is_me = author == 'miller.hall@shopify.com'

  @message = 'Committing working tree' if @message.empty?
  @message = "wip: #{@message}"
  @head_not_on_jj_style_commit = false

  system 'git add .'
  if is_wip && is_me
    system 'git commit --allow-empty --amend --no-edit'
  elsif !has_no_diff
    system %(git commit --allow-empty -m '#{@message}')
  else
    @head_not_on_jj_style_commit = true
  end
end
