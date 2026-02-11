import 'package:flutter/material.dart';
import 'package:nocodb_app_flutter/utils/notify_utils.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/nocodb_service.dart';
import 'package:nocodb_app_flutter/l10n/app_localizations.dart';
import 'full_screen_image_page.dart';

class MistakeBookPage extends StatefulWidget {
  const MistakeBookPage({super.key});

  @override
  State<MistakeBookPage> createState() => _MistakeBookPageState();
}

class _MistakeBookPageState extends State<MistakeBookPage> {
  final NocoDBService _service = NocoDBService();
  final PageController _pageController = PageController();
  
  // Cache for loaded rows
  final Map<int, Map<String, dynamic>> _dataCache = {};
  // Track loading batches (start index)
  final Set<int> _loadingBatches = {};
  // Track errors for each index
  final Map<int, String> _errors = {};
  
  String? _baseUrl;
  int? _maxCount; // To mark the end of the list
  static const int _batchSize = 5;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
    _ensureDataLoaded(0); // Load first batch
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = prefs.getString('nocodb_url');
      if (_baseUrl != null && _baseUrl!.endsWith('/')) {
        _baseUrl = _baseUrl!.substring(0, _baseUrl!.length - 1);
      }
    });
  }

  Future<void> _ensureDataLoaded(int index) async {
    if (_maxCount != null && index >= _maxCount!) return;
    
    // Check if data is already in cache
    if (_dataCache.containsKey(index)) {
      // If we have the current data, check if we need to preload the next batch
      // e.g. if we are at the end of the current batch
      int batchStart = (index ~/ _batchSize) * _batchSize;
      if (index >= batchStart + _batchSize - 2) { // Preload when 2 items left in batch
          _loadBatch(batchStart + _batchSize);
      }
      return;
    }

    // Calculate batch start
    int batchStart = (index ~/ _batchSize) * _batchSize;
    _loadBatch(batchStart);
  }

  Future<void> _loadBatch(int batchStart) async {
    if (_maxCount != null && batchStart >= _maxCount!) return;
    if (_loadingBatches.contains(batchStart)) return;

    // Check if all items in this batch are already cached (edge case)
    bool allCached = true;
    for (int i = 0; i < _batchSize; i++) {
      if (!_dataCache.containsKey(batchStart + i)) {
        allCached = false;
        break;
      }
    }
    if (allCached) return;

    setState(() {
      _loadingBatches.add(batchStart);
      // Clear errors for this batch
      for (int i = 0; i < _batchSize; i++) {
        _errors.remove(batchStart + i);
      }
    });

    try {
      final rows = await _service.fetchRows(batchStart, limit: _batchSize);
      
      if (mounted) {
        setState(() {
          _loadingBatches.remove(batchStart);
          
          if (rows.isEmpty) {
            _maxCount = batchStart;
          } else {
            for (int i = 0; i < rows.length; i++) {
              _dataCache[batchStart + i] = rows[i];
            }
            if (rows.length < _batchSize) {
              _maxCount = batchStart + rows.length;
            } else {
              // Automatically try to preload next batch if this is the first batch
              if (batchStart == 0) {
                 _loadBatch(_batchSize);
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingBatches.remove(batchStart);
          // Mark all items in this batch as errored
          for (int i = 0; i < _batchSize; i++) {
             // Only mark if we haven't reached maxCount (we don't know maxCount yet properly if error)
             // But reasonable to mark them.
             _errors[batchStart + i] = e.toString();
          }
        });
      }
    }
  }

  void _retry(int index) {
    _ensureDataLoaded(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.mistakeBook,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () {
              _dataCache.clear();
              _maxCount = null;
              _loadingBatches.clear();
              _errors.clear();
              _ensureDataLoaded(_pageController.page?.round() ?? 0);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _maxCount,
        onPageChanged: (index) {
          _ensureDataLoaded(index);
          // Aggressive preloading: ensure next few items are available
          _ensureDataLoaded(index + 1);
          _ensureDataLoaded(index + 2);
        },
        itemBuilder: (context, index) {
          if (_dataCache.containsKey(index)) {
            return MistakeQuestionView(
              key: ValueKey('question_$index'),
              row: _dataCache[index]!,
              baseUrl: _baseUrl,
              onNextQuestion: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            );
          } else if (_errors.containsKey(index)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.errorPrefix}${_errors[index]}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _retry(index),
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            );
          } else if (_maxCount != null && index >= _maxCount!) {
             return Center(child: Text(AppLocalizations.of(context)!.noMoreRecords));
          } else {
            // Trigger load if not already loading (though onPageChanged handles most cases)
            _ensureDataLoaded(index);
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class MistakeQuestionView extends StatefulWidget {
  final Map<String, dynamic> row;
  final String? baseUrl;
  final VoidCallback? onNextQuestion;

  const MistakeQuestionView({
    super.key,
    required this.row,
    this.baseUrl,
    this.onNextQuestion,
  });

  @override
  State<MistakeQuestionView> createState() => _MistakeQuestionViewState();
}

class _MistakeQuestionViewState extends State<MistakeQuestionView> with AutomaticKeepAliveClientMixin {
  final NocoDBService _service = NocoDBService();
  final GlobalKey _analysisKey = GlobalKey();
  final GlobalKey _knowledgeKey = GlobalKey();
  String? _selectedOption;
  bool _showImage = false;
  bool _showAnalysisImage = false;
  bool _showKnowledgePointImage = false;

  @override
  bool get wantKeepAlive => true;

  void _submitAnswer() {
    if (_selectedOption == null) {
      NotifyUtils.showNotify(context, '请先选择一个选项');
      return;
    }

    final correctAnswer = widget.row['答案']?.toString().trim();
    if (correctAnswer == null || correctAnswer.isEmpty) {
      NotifyUtils.showNotify(context, '未找到答案数据');
      return;
    }

    bool isCorrect = _selectedOption == correctAnswer;
    if (!isCorrect && _selectedOption != null) {
      final option = _selectedOption!.trim();
      // Check if option starts with answer letter followed by common separators
      if (option.startsWith('$correctAnswer.') ||
          option.startsWith('$correctAnswer、') ||
          option.startsWith('$correctAnswer ')) {
        isCorrect = true;
      }
    }

    _updateStats(isCorrect);

    if (isCorrect) {
      // Auto advance if correct
      widget.onNextQuestion?.call();
    } else {
      // Show analysis and knowledge point if incorrect
      setState(() {
        _showAnalysisImage = true;
        _showKnowledgePointImage = true;
      });
      NotifyUtils.showNotify(context, '回答错误，已自动显示解析');

      // Scroll to analysis or knowledge point
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final contextToScroll = _knowledgeKey.currentContext ?? _analysisKey.currentContext;
          if (contextToScroll != null && contextToScroll.mounted) {
            Scrollable.ensureVisible(
              contextToScroll,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: 0.0,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            );
          }
        }
      });
    }
  }

  Future<void> _updateStats(bool isCorrect) async {
    if (!widget.row.containsKey('Id')) return;

    try {
      int safeInt(dynamic val) {
        if (val is int) return val;
        if (val is double) return val.toInt();
        if (val is String) return int.tryParse(val) ?? 0;
        return 0;
      }

      int answerCount = safeInt(widget.row['总答题次数']);
      int errorCount = safeInt(widget.row['错误次数']);

      Map<String, dynamic> updates = {
        'Id': widget.row['Id'],
        '总答题次数': answerCount + 1,
      };

      if (!isCorrect) {
        updates['错误次数'] = errorCount + 1;
      }

      await _service.updateRow(updates);

      // Update local data
      if (mounted) {
        setState(() {
          widget.row['总答题次数'] = updates['总答题次数'];
          if (!isCorrect) {
            widget.row['错误次数'] = updates['错误次数'];
          }
        });
      } else {
        widget.row['总答题次数'] = updates['总答题次数'];
        if (!isCorrect) {
          widget.row['错误次数'] = updates['错误次数'];
        }
      }
    } catch (e) {
      debugPrint('Error updating stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    List<Widget> children = [];

    // Check for '题目' field and display image if available
    if (widget.row.containsKey('题目')) {
      final questionData = widget.row['题目'];
      if (questionData is List && questionData.isNotEmpty) {
        final firstItem = questionData.first;
        if (firstItem is Map && firstItem.containsKey('signedPath')) {
          final String? signedPath = firstItem['signedPath'];
          if (signedPath != null && signedPath.isNotEmpty) {
            children.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showImage = !_showImage;
                      });
                    },
                    icon: Icon(
                      _showImage ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    label: Text(_showImage ? '隐藏题目图片' : '显示题目图片'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_showImage)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      margin: const EdgeInsets.only(bottom: 24.0),
                      clipBehavior: Clip.antiAlias,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImagePage(
                                    imageUrl: (widget.baseUrl != null
                                            ? '${widget.baseUrl}/'
                                            : '') +
                                        signedPath,
                                  ),
                                ),
                              );
                            },
                            child: Image.network(
                              (widget.baseUrl != null ? '${widget.baseUrl}/' : '') +
                                  signedPath,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('无法加载图片'),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }
        }
      }
    }

    // Process Title
    if (widget.row.containsKey('Title') && widget.row['Title'] != null) {
      final String title = widget.row['Title'].toString();
      if (title.isNotEmpty) {
        children.add(
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Process options
    if (widget.row.containsKey('options') && widget.row['options'] != null) {
      dynamic optionsData = widget.row['options'];
      Map<String, dynamic>? optionsMap;
      if (optionsData is String) {
        try {
          var decoded = jsonDecode(optionsData);
          if (decoded is Map) {
            optionsMap = Map<String, dynamic>.from(decoded);
          } else if (decoded is List) {
            optionsMap = {};
            for (var item in decoded) {
              if (item is String) {
                var parts = item.split('. ');
                if (parts.length > 1) {
                  optionsMap[parts[0]] = parts.sublist(1).join('. ');
                } else {
                  optionsMap[item] = item;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing options: $e');
        }
      } else if (optionsData is Map) {
        optionsMap = Map<String, dynamic>.from(optionsData);
      } else if (optionsData is List) {
        optionsMap = {};
        for (var item in optionsData) {
          if (item is String) {
            var parts = item.split('. ');
            if (parts.length > 1) {
              optionsMap[parts[0]] = parts.sublist(1).join('. ');
            } else {
              optionsMap[item] = item;
            }
          }
        }
      }

      if (optionsMap != null && optionsMap.isNotEmpty) {
        children.add(
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...optionsMap.entries.map((entry) {
                    final isSelected = _selectedOption == entry.key;
                    return CheckboxListTile(
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: isSelected ? Colors.black87 : Colors.black54,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      value: isSelected,
                      activeColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedOption = entry.key;
                          } else {
                            _selectedOption = null;
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ElevatedButton(
                      onPressed: _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '交卷',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Process '解析' field and display image if available
    if (widget.row.containsKey('解析')) {
      final analysisData = widget.row['解析'];
      if (analysisData is List && analysisData.isNotEmpty) {
        final firstItem = analysisData.first;
        if (firstItem is Map && firstItem.containsKey('signedPath')) {
          final String? signedPath = firstItem['signedPath'];
          if (signedPath != null && signedPath.isNotEmpty) {
            children.add(
              Column(
                key: _analysisKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAnalysisImage = !_showAnalysisImage;
                      });
                    },
                    icon: Icon(
                      _showAnalysisImage
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18,
                    ),
                    label: Text(_showAnalysisImage ? '隐藏解析图片' : '显示解析图片'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_showAnalysisImage)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      margin: const EdgeInsets.only(bottom: 24.0),
                      clipBehavior: Clip.antiAlias,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImagePage(
                                    imageUrl: (widget.baseUrl != null
                                            ? '${widget.baseUrl}/'
                                            : '') +
                                        signedPath,
                                  ),
                                ),
                              );
                            },
                            child: Image.network(
                              (widget.baseUrl != null ? '${widget.baseUrl}/' : '') +
                                  signedPath,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('无法加载图片'),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }
        }
      }
    }

    // Process '_nc_m2m_错题集_知识点s' field and display image if available
    if (widget.row.containsKey('_nc_m2m_错题集_知识点s')) {
      final m2mData = widget.row['_nc_m2m_错题集_知识点s'];
      if (m2mData is List && m2mData.isNotEmpty) {
        final firstItem = m2mData.first;
        if (firstItem is Map && firstItem.containsKey('知识点')) {
          final knowledgePoint = firstItem['知识点'];
          if (knowledgePoint is Map && knowledgePoint.containsKey('知识点')) {
            final images = knowledgePoint['知识点'];
            if (images is List && images.isNotEmpty) {
              final firstImage = images.first;
              if (firstImage is Map && firstImage.containsKey('signedPath')) {
                final String? signedPath = firstImage['signedPath'];
                if (signedPath != null && signedPath.isNotEmpty) {
                  children.add(
                    Column(
                      key: _knowledgeKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showKnowledgePointImage =
                                  !_showKnowledgePointImage;
                            });
                          },
                          icon: Icon(
                            _showKnowledgePointImage
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          label: Text(
                            _showKnowledgePointImage
                                ? '隐藏知识点图片'
                                : '显示知识点图片',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_showKnowledgePointImage)
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            margin: const EdgeInsets.only(bottom: 24.0),
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => FullScreenImagePage(
                                              imageUrl: (widget.baseUrl != null
                                                      ? '${widget.baseUrl}/'
                                                      : '') +
                                                  signedPath,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    (widget.baseUrl != null ? '${widget.baseUrl}/' : '') +
                                        signedPath,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text('无法加载图片'),
                                      );
                                    },
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }

    const keys = [
      '题目',
      'Id',
      'CreatedAt',
      'UpdatedAt',
      'Title',
      '解析',
      '答案',
      '错误次数',
      '总答题次数',
      '知识点',
      '知识点 (from 知识点)',
      '_nc_m2m_错题集_知识点s',
      '小节',
      'options',
      '解析按钮'
    ];
    children.addAll(
      widget.row.entries.where((entry) => !keys.contains(entry.key)).map((
        entry,
      ) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: children,
    );
  }
}
