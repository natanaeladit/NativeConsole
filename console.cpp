// console.cpp : Defines the entry point for the application.
//

#include "console.h"

using namespace std;

int main()
{
	cout << "Hello CMake from Linux." << '\n';

	constexpr int a = 11;
	constexpr int b = 12;
	const auto c = add(a, b);
	cout << a << " + " << b << " = " << c << '\n';

	cout << "Done." << '\n';
	return 0;
}