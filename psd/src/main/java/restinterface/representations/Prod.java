package main.java.restinterface.representations;

import com.fasterxml.jackson.annotation.*;

public class Prod {
    public final String name;
	public final int min;
	public final int max;
	public final int price;
	public final String data;
    @JsonCreator
    public Prod(@JsonProperty("name") String name, @JsonProperty("min") int min, @JsonProperty("max") int max,
    			@JsonProperty("price") int price, @JsonProperty("data") String data) {
      	this.name = name;
		this.min = min;
		this.max = max;
		this.price = price;
		this.data = data;
    }
}

