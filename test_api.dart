import 'lib/core/services/rapid_api_service.dart';
import 'lib/core/utils/constants.dart';

void main() async {
  print('🔑 API Key: ${AppConstants.rapidApiKey}');
  print('✅ Valid: ${RapidApiService.hasValidApiKey}');
  
  if (RapidApiService.hasValidApiKey) {
    print('🎉 API Key is properly configured!');
  } else {
    print('❌ Please add your RapidAPI key to .env file');
  }
}