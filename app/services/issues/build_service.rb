module Issues
  class BuildService < Issues::BaseService
    include ResolveDiscussions

    def execute
      filter_resolve_discussion_params
      @issue = project.issues.new(issue_params)
    end

    def issue_params_with_info_from_discussions
      return {} unless merge_request_to_resolve_discussions_of

      { title: title_from_merge_request, description: description_for_discussions }
    end

    def title_from_merge_request
      "Follow-up from \"#{merge_request_to_resolve_discussions_of.title}\""
    end

    def description_for_discussions
      if discussions_to_resolve.empty?
        return "There are no unresolved discussions. "\
               "Review the conversation in #{merge_request_to_resolve_discussions_of.to_reference}"
      end

      description = "The following #{'discussion'.pluralize(discussions_to_resolve.size)} "\
                    "from #{merge_request_to_resolve_discussions_of.to_reference} "\
                    "should be addressed:"

      [description, *items_for_discussions].join("\n\n")
    end

    def items_for_discussions
      discussions_to_resolve.map { |discussion| item_for_discussion(discussion) }
    end

    def item_for_discussion(discussion)
      first_note = discussion.first_note_to_resolve || discussion.first_note
      other_note_count = discussion.notes.size - 1
      note_url = Gitlab::UrlBuilder.build(first_note)

      discussion_info = "- [ ] #{first_note.author.to_reference} commented on a [discussion](#{note_url}): "
      discussion_info << " (+#{other_note_count} #{'comment'.pluralize(other_note_count)})" if other_note_count > 0

      note_without_block_quotes = Banzai::Filter::BlockquoteFenceFilter.new(first_note.note).call
      spaces = ' ' * 4
      quote = note_without_block_quotes.lines.map { |line| "#{spaces}> #{line}" }.join

      [discussion_info, quote].join("\n\n")
    end

    def issue_params
      @issue_params ||= issue_params_with_info_from_discussions.merge(whitelisted_issue_params)
    end

    def whitelisted_issue_params
      if can?(current_user, :admin_issue, project)
        params.slice(:title, :description, :milestone_id)
      else
        params.slice(:title, :description)
      end
    end
  end
end
