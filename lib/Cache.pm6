use Heap;
sub default-lambda(:$touched) {$touched}

role Cache::Item[&lambda] {
	has Int 	$!touched;
	has Mu		$.value		is rw;

	method sort-number {
		lambda |&lambda.signature.params.map: {
			my $name = .name.subst: 1;
			$name => self."{$name}"()
		}
	}

	method touch { $!touched++ }
}

role Cache[&lambda = &default-lambda] {
	has			$.key;
	has 		$!heap				= Heap[ *.sort-number ].new;
	has 		$!hash;
	has Bool	$.touch-on-create	= True;
	has UInt	$.size				= 1024;

	method !limit {
		for (+$!heap + 1) .. $!size {
			$!hash{$!heap.pop}:delete
		}
	}

	method set(Pair (Str :$key, Mu :$value)) {
		if $!hash{$key}:exists {
			$!hash{$key}.value = $value
		} else {
			self!limit;
			$!heap.push: $!hash{$key} = Cache::Item[&lambda].new: :key($key), :value($value)
		}
		$!hash{$key}.touch if $!touch-on-create;
		$value
	}

	method get(Str $key) {
		given $!hash{$key} {
			.touch;
			.value
		}
	}
}
