// ITSC 204 - Lab 1 Example
// Binary to Decimal conversion
// Created by Lubos Kuzma
// ISS, SADT, SAIT
// August 2022

// compile with:
// gcc BinToDec.c -o BinToDec -lm

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>



char * verify(char input[]) {
    // Entry verification
    // exits program if:
    // not binary (other than 0 or 1 entered)
    // or mroe than 16 characters


    for (int i = 0; i < strlen(input); i++){
        if ((input[i] - '0' != 0) && (input[i] - '0' != 1)) {               // if not binary
            printf("Number entered is not in binary format.");              // "input[i] = '0'" is used to change from char (ASCII)
            exit(1);                                                        // to integer
        } 
    }

    if (strlen(input) > 16){                                                // if more than 16
        printf("You have entered too many digits. Enter precisely 16 bits.");    
        exit(1);
    } else if(strlen(input) < 16)   {
        printf("You have entered too few digits. Enter precisely 16 bits.");
        exit(1);
     }


    return input;                                                           // returns the pointer
}

void step_1(char input[], int step_2_array[]) {
    // Step through all elemenets in the input 
    // then calculate 2^n for each binary place
    // multiply this by 0 or 1
    // and save each output to an array

    // Array is larger than elements in input by 1.
    // This space is (step_2_array[0]) is used to pass the number of elements to Step 2.

    step_2_array[0] = strlen(input);                                        // save the index of last element into array[0]
    
    printf("Step 1:\n\n");
    for (int x = 0; x < strlen(input); x++) {                               // step through the input
        int rev_x = (strlen(input) - x - 1);                                // Reversed order of digits (MSB first)
        double exponent =  pow(2.0, (double)x);                             // calculate the 2^n
        double multi = exponent * (input[rev_x] - '0');                          // multiply the 2^n by input[n]
        printf("Digit #%d => %c times \t%d (2^%d) => \t\t%d\n", x, input[rev_x], (int)exponent, x, (int)multi);
        step_2_array[x+1] = (int)multi;                                     // save the results to an array
    }

}

void step_2(int * step_2_array) {
    // Step 2 will sum all elemenets of an array
    // print each element and the results
    
    int array_sum = 0;                                                      // inititalize the sum                                              

    printf("\nStep 2:\n\n");                                    
    for (int y = 1; y <= step_2_array[0]; y++) {                            // step through each element in the array

        array_sum += step_2_array[y];                                       // add each elemenet to the sum

        printf("%d", step_2_array[y]);
        if (y < step_2_array[0] - 1){                                       // print + or = dependent where in array we are
            printf(" + ");    
        } else {
            printf(" = ");
        }
        
    }

    printf("%d\n\n", array_sum);
    
}

void main() {
    char * bin_input = malloc(16 * sizeof(char));           // allocate memory for binary input
    int * array_buffer = malloc(16 * sizeof(int));          // allocate memory for integer array needed in Step 2

    printf("Enter 16 bit binary number:\n");                
    scanf("%s", bin_input);
    printf("\n");

    char * number = verify(bin_input);                      // verify that string entered is binary and not more than 16 bits

    step_1(number, array_buffer);
    step_2(array_buffer);
    
    free(bin_input);                                        // release the memory. this is not necessary since the program
    free(array_buffer);                                     // terminates right after this, but it's a good practice

  
}
    



