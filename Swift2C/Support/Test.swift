
// This is a test program which can be compiled by the Taste-compiler.
// It reads a sequence of numbers and computes the sum of all integers 
// up to these numbers.

class Test {
    var i: Int
	
	func Foo() {
        var a: Int; var b: Int; var max: Int
//        read(a); read(b)
        if a > b { max = a } else { max = b }
//		print(max)
	}

	func SumUp() {
        var sum: Int
		sum = 0
        while i > 0 { sum = sum + i; i = i - 1 }
//		print(sum)
	}

	func Main() {
//		read(i)
        while i > 0 {
			SumUp()
//			read(i)
        }
	}
}

