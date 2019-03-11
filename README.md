# RuntimeLearn
学习Runtime  笔记

### 1、Objective-C中类和实例对象

```
OC 中类的本质是一个结构体
```
![实现图](https://user-gold-cdn.xitu.io/2019/1/24/1687e837aa327914?imageView2/0/w/1280/h/960/ignore-error/1)
NSObject类中存在一个Class类型的 isa 指针。我们在Xcode编写一个类继承于NSObject ，在用命令行 使用 ` xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc xx.m -o xx.cpp`，将.m文件转成.cpp 文件，窥探NSObject的底层实现。
![](https://user-gold-cdn.xitu.io/2019/1/24/1687e837a90f372d?imageView2/0/w/1280/h/960/ignore-error/1)
我们发现  `typedef struce obj_object NSObject ` 定义的结构体，这大概就是 NSObject 的底层实现了，其实就是C语言中的结构体。

### 有继承关系的类
--
定义一个Student 继承自 Person 的类，可以通过下图看到 Person和Student之间的关系

![实现图](https://user-gold-cdn.xitu.io/2019/1/24/1687e837c961ddb3?imageView2/0/w/1280/h/960/ignore-error/1)
--
### Objc 对象的分类
```
  OC中对象主要可以分成实例对象，类对象，元类对象 三种。
```
### instance 对象（实例对象)
>    instance 对象就是通过类 alloc 出来的，实例对象中存储着一个 isa 指针和一些成员变量。

### class 对象（类对象)
>    每个类有且只有一个类对象，class对象中存放着一个isa 指针，一个superclass指针，类的属性信息，类的对象方法信息，类的协议方法信息，类的成员变量信息等，其本质是一个 objc_class 的结构体。

### meta-class 对象（元类对象)
>    每个类有且只有一个元类对象，元类对象的结构跟类对象是一样的，只不过用途不一样，可以通过 runtime的 `class_isMetaClass` 来验证某个类是不是元类，其本质是一个 objc_class的结构体。

## isa 和 superclass 
![](https://user-gold-cdn.xitu.io/2019/1/24/1687e837e5f6cea8?imageView2/0/w/1280/h/960/ignore-error/1)
从上图我们可以看出：

* `instance` 的 `isa` 指针指向 `class`，`class` 的`isa`  指针指向 `meta-class` ，而 `metaclass` 的 `isa` 指针指向 `root-class`
* `subclass` 的 `superclass` 指针指向`superclass`，依次直到 root-class，`root-class` 的`superclass` 指针为 `nil` 。`meta-class` 的`superclass` 指针指向其 `superclass`的`meta-class`，依次到 `rootclass` ,`rootclass`的`superclass`指向`rootclass`的`class`。
* 而`subclass` 和 `superclass`的`isa`以及 `meta-class` 的`isa`指针皆指向 `meta-class`的`rootclass`
* `instance` 调用实例方法的轨迹：通过`isa`找`class` 找不到就通过`superclass`找父类。
* `class` 调用类对象的轨迹：通过 `isa`找`meta-class`，找不到就通过`superclass`找父类。


--
# Runtime
描述：**OC是一门动态语言，会将程序的一些决定工作从编译期推迟到运行期**，由于OC语言运行时的特性，所以其不只需要依赖编译器，还需要依赖运行时环境。
OC 语言在编译期都会被编译为C语言的`Runtime`代码，二进制执行中执行的都是C语言代码。而OC的类本质上都是结构体，在编译时都会以结构体的形式被编译到二进制中。`Runtime` 是一套由 C 、C++ 汇编实现的API，所有的方法调用，都叫做发消息。
`Runtime` 不只是一些 C语言的API ，它是由`Class`、`Mete Class`、`Instance`、`Class Instance` 组成，是**一套完整的面向对象的数据结构，所以研究Runtime整体的对象模型，比研究API是怎么实现的更有意义。**

###使用Runtime
`Runtime` 是一个共享动态库，它的目录位于`/usr/include/objc` 由一系列的C函数和结构体构成。和`Runtime`系统发生交互的方式有三种，一般用前两种：
1.   使用OC源码，直接使用上层OC源码，底层会通过`Runtime`为其提供运行支持，上层不需要关心`Runtime`运行。
2. `NSObject` 在OC代码中绝大多数的类都是继承自`NSObject`的，**`NSProxy`类例外**。`Runtime`在`NSObject`中定义了一些基础操作，`NSObject`的子类也具备这些特性。
3. `Runtime`动态库 上层的 OC源码都是通过 `Runtime`实现的，我们一般不直接使用`Runtime`，直接和OC代码打交道就可以了。


### IMP
--
在`Runtime`中`IMP` 本质上就是一个函数指针，其定义如下。在`IMP`中两个默认的参数`id`和`SEL`，`id`也就是方法中的`self`，这和`objc_msgSend()` 函数传递的参数是一样的。

``` swift
typedef  void() (*IMP)(void /* id, SEL ,  参数...*/)
//获取 IMP 有两个方法，可以根据传入的 SEL 获取到对应的IMP 
- (IMP)methodForSelector:(SEL)aSelector;// 实例对象可以调用，类对象也可以调用。
+ (IMP)instanceMethodForSelector:(SEL)aSelector;

//调用
- (void)getMethodName {
    // 创建C函数指针 用来接收IMP
    void(*function)(id,SEL,NSObject*);
    
    function = (void(*)(id, SEL, NSObject*)) [self methodForSelector:@selector(readView:)];
    
    function(self,@selector(readView:),UIColor.redColor);
}
- (void)readView:(UIColor *)color{
    self.view.backgroundColor = [UIColor redColor];
}
```
> 通过这些 `API` 可以进行一些优化操作，如果遇到大量的方法执行，可以通过 `Runtime` 获取到 `IMP`，直接调用 `IMP` 实现优化。
**在获取和调用`IMP`的时候需要注意，每个方法默认都有两个隐藏参数（id,SEL），所以在函数声明的时候需要加上这两个隐藏参数，调用的时候也需要把相应的 对象 和`SEL`传进去，否则可能会导致`Crash`**

### IMP For Block
`Runtime` 还支持 `Block` 方式的回调，我们可以通过 `Runtime`的API ，将原来的方法回调改为`Block` 的回调。

```  swift
// 类定义
- (void)testMethod:(NSString *)text;
// 类实现 
- (void)testMethod:(NSString *)tex{
    NSLog(@"父类%@",tex);
}

// 子类修改
   IMP function = imp_implementationWithBlock(^(id self,NSString *text){
         NSLog(@"%@",text);
    });
    const char *types = sel_getName(@selector(testMethod:));
    class_replaceMethod([subTestObject class],@selector(testMethod:),function,types);
    [self testMethod:@"hahahh"];
 
```
## Method
`Method` 用来表示方法，其中包含`SEL`和`IMP`，`Method`结构定义如下

``` swift
typedef struct method_t *Method;
struct method_t {
                   SEL name;
                   const char *types;
                   IMP imp;
}
```
在 Xcode 进行编译的时候，只会将 Xcode 的`Compile Sources`中`.m`声明的方法编译到 `MethodList`，而`.h` 文件中声明的方法对 `Method List`没有影响。

## Property
在`Runtime`中定义了属性的结构体，用来表示对象中定义的属性，`@Property` 修饰符用来修饰属性，修饰后的属性为 `objc_property_t` 类型，其本质是 `property_t` 结构体。器结构体定义如下。

``` swift
  typedef struct property_t *objc_property_t;
  struct property_t {
           const char *name;
           const char *attributes;
  }
```
可以通过 下面两个函数，分别获取对象的属性列表，和协议的属性列表。

```swift
    objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount)
    objc_property_t *protocol_copyPropertyList(Protocol *proto,unsigned int *outCount)
```
可以通过下面两个方法 传入指定的`Class`和`propertyName`, 获取对应的 `objc_property_t`属性结构体。

```swift
objc_property_t class_getProperty(Class cls, const char * name)
objc_property_t protocol_getProperty(Protocol *proto, const char*name BOOL isRequiredProperty, BOOL isInstanceProperty)
```

# 分析实例变量
--








