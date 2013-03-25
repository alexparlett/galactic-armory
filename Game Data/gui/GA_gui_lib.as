int findString(string@[] arr, string@ str) {
	for(uint i = 0; i < arr.length(); i++) {
		if(arr[i].opEquals(str))
			return 1;
	}		
	return 0;
}