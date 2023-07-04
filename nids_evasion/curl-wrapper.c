#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <curl/curl.h>

// HTTP response data structure
struct ResponseData {
	char* data;
	size_t size;
};

// Writing callback function
size_t write_callback(char* ptr, size_t size, size_t nmemb, void* userdata) {
	struct ResponseData* response = (struct ResponseData*)userdata;
	size_t response_size = size * nmemb;
	size_t new_size = response->size + response_size;

	response->data = realloc(response->data, new_size + 1);
	if (response->data == NULL) {
		printf("ERROR: Allocation fault.\n");
		return 0;
	}

	// Copy the response data to the response structure
	memcpy(response->data + response->size, ptr, response_size);
	response->size = new_size;

	// Add the null terminator
	response->data[response->size] = '\0';

	return response_size;
}

// Main function
int main(int argc, char* argv[]) {
	if (argc != 2) {
		printf("Usage: %s <URL>\n", argv[0]);
		return 1;
	}

	CURL* curl;
	CURLcode res;
	char* url = argv[1];

	// Init libcurl
	curl_global_init(CURL_GLOBAL_DEFAULT);

	// Init the cURL session
	curl = curl_easy_init();
	if (curl) {
		// Set URL for the request
		curl_easy_setopt(curl, CURLOPT_URL, url);

		// Create a struct to store the response data
		struct ResponseData response;

		// Set to empty
		response.data = malloc(1); 
		response.size = 0;

		// Set the callback function
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);

		// Pass the struct to the callback function
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

		// Exec the request
		res = curl_easy_perform(curl);

		// Looking for the string "uid=0(root) gid=0(root) groups=0(root)"
		char* search_string = "uid=0(root) gid=0(root) groups=0(root)";
		if (res == CURLE_OK && strstr(response.data, search_string) != NULL) {
			printf(response.data);

			FILE* log_file = fopen("curl.log", "a");
			if (log_file != NULL) {
				// Ottieni il timestamp corrente
				time_t now = time(NULL);
				struct tm* timeinfo = localtime(&now);
				char timestamp[20];
				strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", timeinfo);

				// Write the log
				fprintf(log_file, "[%s][!WARNING] '%s' detected.\n", timestamp, search_string);

				// Close the log file
				fclose(log_file);
			} else {
				printf("Error in writing log file log.\n");
			}
		}

		free(response.data);
		// Cleanup
		curl_easy_cleanup(curl);
	}

	curl_global_cleanup();

	return 0;
}
