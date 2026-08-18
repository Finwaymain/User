import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../constant/constant.dart';
import '../model/support_chat_model.dart';
import '../service/api.dart';
import '../utils/Preferences.dart';

class SupportChatController extends GetxController {
  final String userType; // 'customer' or 'business'

  SupportChatController({this.userType = 'customer'});

  var isLoading = true.obs;
  var isSending = false.obs;
  var ticket = Rxn<SupportTicketModel>();
  var quickQuestions = <SupportQuickQuestionModel>[].obs;
  var messages = <SupportMessageModel>[].obs;

  final TextEditingController messageInputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Timer? _pollTimer;
  int _lastMessageId = 0;

  @override
  void onInit() {
    super.onInit();
    initChat();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    messageInputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> initChat() async {
    isLoading.value = true;
    await Future.wait([
      fetchQuickQuestions(),
      getOrCreateTicket(),
    ]);
    if (ticket.value != null) {
      await fetchMessages();
      _startPolling();
    }
    isLoading.value = false;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (ticket.value != null) {
        fetchNewMessages();
      }
    });
  }

  Future<void> fetchQuickQuestions() async {
    try {
      final url = Uri.parse('${API.supportQuickQuestions}?user_type=$userType');
      final res = await http.get(url, headers: API.header);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] is List) {
          quickQuestions.value = (body['data'] as List)
              .map((q) => SupportQuickQuestionModel.fromJson(q))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching quick questions: $e');
    }
  }

  String _getUserId() {
    final fromPrefs = Preferences.getString(Preferences.userId);
    if (fromPrefs.isNotEmpty) return fromPrefs;
    final intId = Preferences.getInt(Preferences.userId);
    if (intId != 0) return intId.toString();
    return Constant.getUserData().data?.id?.toString() ?? '1';
  }

  String _getUserName() {
    final data = Constant.getUserData().data;
    if (data != null) {
      final name = '${data.prenom ?? ''} ${data.nom ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    return 'Customer';
  }

  Future<void> getOrCreateTicket() async {
    try {
      final userId = _getUserId();
      final bodyData = {
        'user_id': userId,
        'user_type': userType,
        'topic': 'General Support',
      };

      final res = await http.post(
        Uri.parse(API.supportTicket),
        headers: API.header,
        body: json.encode(bodyData),
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] != null) {
          ticket.value = SupportTicketModel.fromJson(body['data']);
        }
      }
    } catch (e) {
      debugPrint('Error initializing ticket: $e');
    }
  }

  Future<void> fetchMessages() async {
    if (ticket.value == null) return;
    try {
      final url = Uri.parse('${API.supportMessages}?ticket_id=${ticket.value!.id}');
      final res = await http.get(url, headers: API.header);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] is List) {
          final list = (body['data'] as List)
              .map((m) => SupportMessageModel.fromJson(m))
              .toList();
          messages.value = list;
          if (list.isNotEmpty) {
            _lastMessageId = list.last.id;
          }
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<void> fetchNewMessages() async {
    if (ticket.value == null) return;
    try {
      final url = Uri.parse('${API.supportMessages}?ticket_id=${ticket.value!.id}&after_id=$_lastMessageId');
      final res = await http.get(url, headers: API.header);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] is List) {
          final newMsgs = (body['data'] as List)
              .map((m) => SupportMessageModel.fromJson(m))
              .toList();
          if (newMsgs.isNotEmpty) {
            messages.addAll(newMsgs);
            _lastMessageId = newMsgs.last.id;
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint('Error polling new messages: $e');
    }
  }

  Future<void> sendUserMessage({String? customText, int? questionId}) async {
    final text = customText ?? messageInputController.text.trim();
    if (text.isEmpty || ticket.value == null) return;

    messageInputController.clear();
    isSending.value = true;

    try {
      final userId = _getUserId();
      final senderName = _getUserName();

      final bodyData = {
        'ticket_id': ticket.value!.id,
        'user_id': userId,
        'user_type': userType,
        'sender_name': senderName,
        'message': text,
        if (questionId != null) 'question_id': questionId,
      };

      final res = await http.post(
        Uri.parse(API.supportSendMessage),
        headers: API.header,
        body: json.encode(bodyData),
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final data = body['data'];
          if (data['user_message'] != null) {
            final uMsg = SupportMessageModel.fromJson(data['user_message']);
            messages.add(uMsg);
            if (uMsg.id > _lastMessageId) _lastMessageId = uMsg.id;
          }
          if (data['auto_reply'] != null) {
            final aMsg = SupportMessageModel.fromJson(data['auto_reply']);
            messages.add(aMsg);
            if (aMsg.id > _lastMessageId) _lastMessageId = aMsg.id;
          }
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      isSending.value = false;
    }
  }

  void onQuestionSelected(SupportQuickQuestionModel question) {
    sendUserMessage(customText: question.question, questionId: question.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
