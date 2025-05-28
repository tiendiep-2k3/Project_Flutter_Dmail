class SearchFilter {
  final String keyword;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? hasAttachments;
  final String? senderEmail;
  final List<String> labelIds;

  SearchFilter({
    this.keyword = '',
    this.startDate,
    this.endDate,
    this.hasAttachments,
    this.senderEmail,
    this.labelIds = const [],
  });

  bool get isEmpty =>
      keyword.isEmpty &&
      startDate == null &&
      endDate == null &&
      hasAttachments == null &&
      senderEmail == null &&
      labelIds.isEmpty;

  SearchFilter copyWith({
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
    bool? hasAttachments,
    String? senderEmail,
    List<String>? labelIds,
  }) {
    return SearchFilter(
      keyword: keyword ?? this.keyword,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      senderEmail: senderEmail ?? this.senderEmail,
      labelIds: labelIds ?? this.labelIds,
    );
  }
}