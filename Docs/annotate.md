### Annotation mechanism for heterogeneous memory

```
#ifdef CONFIG_HETERO_ENABLE
        if (is_hetero_obj(hetero_obj)){
	
        }
#endif
```


* Mark the file mapping to Hetero target object

```
/*Mark the mapping to Hetero target object*/
#ifdef CONFIG_HETERO_ENABLE
        set_fsmap_hetero_obj(inode->i_mapping);
#endif
```

* Mark the socket to Hetero target object
```
/*Mark the socket to Hetero target object*/
#ifdef CONFIG_HETERO_ENABLE
        set_sock_hetero_obj(sock);
#endif
```

