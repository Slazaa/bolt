# The Bolt programming language
> [!WARNING]
> This project is still in heavy developpement. It is not advised to use it in production already.

A purely functionnal programming language designed for high intensity
computations through parallelism. This language does not support I/O, this 
includes for instance operations such as writing or reading files, sockets, and
any operation that can impact the outside of the program.

`example.bolt`
```bolt
fac 0 = 1
fac n = * n (fac (- n 1))
```

You can then evaluate `fac 5` this way:
```
> bolt eval example.bolt "fac 5"
120
```

Or translate the file to bitcode:
```
> bolt bitcode example.bolt
```

And then evaluate `fac 5` like above:
```
> bolt eval example.nut "fac 5"
120
```

## Documentation
No documentation is available yet.

## Support
You can support me on Patreon
https://www.patreon.com/Slazaa
